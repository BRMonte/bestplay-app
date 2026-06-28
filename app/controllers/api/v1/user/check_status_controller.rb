module Api
  module V1
    module User
      class CheckStatusController < ApplicationController
        def create
          result = CheckStatusService.new(
            idfa: check_status_params.fetch(:idfa),
            rooted_device: ActiveModel::Type::Boolean.new.cast(check_status_params.fetch(:rooted_device)),
            ip: request.remote_ip,
            country: request.headers["CF-IPCountry"]
          ).call

          render json: result
        end

        private

        def check_status_params
          params.permit(:idfa, :rooted_device)
        end
      end
    end
  end
end
